import './CommentBody.css'

type CommentBodyProps = {
  text: string
}

export function CommentBody({ text }: CommentBodyProps) {
  return <p className="comment-body">{text}</p>
}
